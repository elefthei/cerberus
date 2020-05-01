open Pp_tools


type 'bound t = {name: Sym.t; bound: 'bound}

let pp pp_bound {name;bound} = 
  PPrint.parens (typ (Sym.pp name) (pp_bound bound))



let subst sym with_it b = 
  { name = Sym.subst sym with_it b.name;
    bound = VarTypes.subst sym with_it b.bound }
