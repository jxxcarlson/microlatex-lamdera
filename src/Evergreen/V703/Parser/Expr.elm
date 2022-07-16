module Evergreen.V703.Parser.Expr exposing (..)

import Evergreen.V703.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V703.Parser.Meta.Meta
    | Text String Evergreen.V703.Parser.Meta.Meta
    | Verbatim String String Evergreen.V703.Parser.Meta.Meta
