module Evergreen.V704.Compiler.Lambda exposing (..)

import Evergreen.V704.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V704.Parser.Expr.Expr
    }
