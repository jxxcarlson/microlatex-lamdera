module Evergreen.V195.Compiler.Lambda exposing (..)

import Evergreen.V195.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V195.Parser.Expr.Expr
    }
