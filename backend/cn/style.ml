let style = "@import url('https://fonts.googleapis.com/css2?family=Source+Code+Pro&display=swap');

* {
    font-size: 10.5pt
}

html {
    font-family: 'Source Code Pro', monospace;;
    padding: 0;
    margin: 0;
    /* font-size: 8pt; */
}

body {
    padding: 0;
    margin: 0;
}

table {
    border: 1px solid;
    border-collapse: collapse;
    /* max-width: 1400px; */
    /* table-layout: fixed; */
}

tr {
    padding : 0;
    margin : 0;
}

th, td {
    text-align: left;
    vertical-align: top;
    border-left: 1px solid;
    border-right: 1px solid;
    padding-left: 5px;
    padding-right: 5px;
    padding-top: 3px;
    padding-bottom: 3px;
}

th {
    padding-top: 5px;
    padding-bottom: 5px;
}



.loc_v {
    text-align: right;
}


@media (prefers-color-scheme: dark) {

    html {
        background-color: black;
        color: lightgray;
    }

    table, th, td {
        border-color: #202020;
    }

    th {
        color: white;
        background-color: #202020;
    }

    tr:hover {
        background-color: #101010;
        color: cyan;
    }
}



@media (prefers-color-scheme: light) {

    html {
        background-color: white;
        color: black;
    }

    table, th, td {
        border-color: #DFDFDF;
    }

    th {
        color: black;
        background-color: #DFDFDF;
    }

    tr:hover {
        background-color: #E2F0FF;
        color: black;
    }
}
"
