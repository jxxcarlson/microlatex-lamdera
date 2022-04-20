module Evergreen.V428.Compiler.Lambda exposing (..)

import Evergreen.V428.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V428.Parser.Expr.Expr
    }
