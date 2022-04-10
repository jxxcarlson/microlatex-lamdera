module Evergreen.V342.Compiler.Lambda exposing (..)

import Evergreen.V342.Parser.Expr


type alias Lambda =
    { name : String
    , vars : List String
    , body : Evergreen.V342.Parser.Expr.Expr
    }
