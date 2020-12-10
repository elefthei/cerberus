open Pp
(* open Resultat
 * open TypeErrors *)

module SymSet = Set.Make(Sym)
module SymMap = Map.Make(Sym)
module IdMap = Map.Make(Id)
module CF = Cerb_frontend
module Loc = Locations
module LC = LogicalConstraints
module RE = Resources
module IT = IndexTerms
module BT = BaseTypes
module LS = LogicalSorts
module LRT = LogicalReturnTypes
module RT = ReturnTypes
module LFT = ArgumentTypes.Make(LRT)
module FT = ArgumentTypes.Make(RT)



type resource_predicate = 
  { arguments : (string * LS.t) list;
    pack_functions : IT.t -> (LFT.t List1.t);
    unpack_functions : IT.t -> (LFT.t List1.t);
  }


let builtin_predicates = IdMap.empty




(* Auxiliaries *)

module ImplMap = 
  Map.Make
    (struct 
      type t = CF.Implementation.implementation_constant
      let compare = CF.Implementation.implementation_constant_compare 
     end)




let impl_lookup (e: 'v ImplMap.t) i =
  match ImplMap.find_opt i e with
  | None ->
     Debug_ocaml.error
       ("Unbound implementation defined constant " ^
          (CF.Implementation.string_of_implementation_constant i))
  | Some v -> v


type closed_stored_predicate_definition =
  { pack_function: IT.t -> LFT.t; 
    unpack_function: IT.t -> LFT.t; 
  }


type struct_piece = 
  { offset: Z.t;
    size: RE.size;
    member_or_padding: (BT.member * Sctypes.t) option }

type struct_member = 
  { offset: Z.t;
    size: RE.size;
    member: BT.member * Sctypes.t }

type struct_decl = 
  { layout: struct_piece list;
    (* sizes: (BT.member * RE.size) list;
     * offsets: (BT.member * Z.t) list;
     * representable: IT.t -> LC.t; *)
    (* closed: RT.t;  *)
    (* closed_stored: RT.t; *)
    closed_stored_predicate_definition: 
      closed_stored_predicate_definition
  }

let members = 
  List.filter_map (fun {member_or_padding; offset; size} ->
      Option.bind member_or_padding (fun (member, sctype) ->
          Some {offset; size; member = (member, sctype)}
        )
    )

let member_types =
  List.filter_map (fun {member_or_padding; _} ->
      Option.bind member_or_padding (fun (member, sctype) ->
          Some (member, sctype)
        )
    )

type struct_decls = struct_decl SymMap.t



module BTMap = Map.Make(BT)


type t = 
  { struct_decls : struct_decls; 
    fun_decls : (Loc.t * FT.t) SymMap.t;
    impl_fun_decls : (FT.t) ImplMap.t;
    impl_constants : BT.t ImplMap.t;
    stdlib_funs : SymSet.t;
    resource_predicates : resource_predicate IdMap.t;
    solver_context : Z3.context;
    (* solver_bt_mapping : Z3.Sort.sort BTMap.t; *)
  } 

let empty solver_context = 
  { struct_decls = SymMap.empty; 
    fun_decls = SymMap.empty;
    impl_fun_decls = ImplMap.empty;
    impl_constants = ImplMap.empty;
    stdlib_funs = SymSet.empty;
    resource_predicates = builtin_predicates;
    solver_context;
    (* solver_bt_mapping = BTMap.empty; *)
  }

let get_predicate_def loc global predicate_name = 
  let open Resources in
  match predicate_name with
  | Id id -> IdMap.find_opt id global.resource_predicates
  | Tag tag ->
     match SymMap.find_opt tag global.struct_decls with
     | None -> None
     | Some decl ->
       let pack_functions = 
         fun it -> 
         List1.one (decl.closed_stored_predicate_definition.pack_function it)
       in
       let unpack_functions = 
         fun it -> 
         List1.one (decl.closed_stored_predicate_definition.unpack_function it)
       in
       Some {arguments = [("value", LS.Base (Struct tag))];
             pack_functions; 
             unpack_functions}

let get_fun_decl global sym = SymMap.find_opt sym global.fun_decls
let get_impl_fun_decl global i = impl_lookup global.impl_fun_decls i
let get_impl_constant global i = impl_lookup global.impl_constants i



let pp_struct_decl (tag,decl) = 
  item ("struct " ^ plain (Sym.pp tag) ^ " (raw)") 
       (Pp.list (fun {offset; size; member_or_padding} -> 
            match member_or_padding with 
            | Some (member, sct) -> 
               typ (Id.pp member) (Sctypes.pp sct)
            | None ->
               parens (!^"padding" ^^^ Z.pp size)
          ) decl.layout
       )
  ^/^
  (* item ("struct " ^ plain (Sym.pp tag) ^ " (closed stored)") 
   *      (RT.pp decl.closed_stored)
   * ^/^ *)
  item ("struct " ^ plain (Sym.pp tag) ^ " (packing function) at P") 
    (LFT.pp
       (decl.closed_stored_predicate_definition.pack_function
          (IT.S (Struct tag, Sym.fresh_named "P"))))
  ^/^
  item ("struct " ^ plain (Sym.pp tag) ^ " (unpacking function) at P") 
    (LFT.pp
       (decl.closed_stored_predicate_definition.unpack_function
          (IT.S (Struct tag, Sym.fresh_named "struct_pointer"))))

let pp_struct_decls decls = Pp.list pp_struct_decl (SymMap.bindings decls) 

let pp_fun_decl (sym, (_, t)) = item (plain (Sym.pp sym)) (FT.pp t)
let pp_fun_decls decls = flow_map hardline pp_fun_decl (SymMap.bindings decls)

let pp global = 
  pp_struct_decls global.struct_decls ^^ hardline ^^
  pp_fun_decls global.fun_decls





