module Evergreen.V655.Parser.Expr exposing (..)

import Evergreen.V655.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V655.Parser.Meta.Meta
    | Text String Evergreen.V655.Parser.Meta.Meta
    | Verbatim String String Evergreen.V655.Parser.Meta.Meta
