module Evergreen.V703.Compiler.Lambda exposing (..)

import Evergreen.V703.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V703.Parser.Expr.Expr
    }
