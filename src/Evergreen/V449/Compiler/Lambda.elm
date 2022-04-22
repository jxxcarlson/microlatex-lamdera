module Evergreen.V449.Compiler.Lambda exposing (..)

import Evergreen.V449.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V449.Parser.Expr.Expr
    }
