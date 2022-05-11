module Evergreen.V506.Compiler.Lambda exposing (..)

import Evergreen.V506.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V506.Parser.Expr.Expr
    }
