module Evergreen.V77.Parser.Expr exposing (..)

import Evergreen.V77.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V77.Parser.Meta.Meta
    | Text String Evergreen.V77.Parser.Meta.Meta
    | Verbatim String String Evergreen.V77.Parser.Meta.Meta
    | Error String
