module Evergreen.V31.Parser.Expr exposing (..)

import Evergreen.V31.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V31.Parser.Meta.Meta
    | Text String Evergreen.V31.Parser.Meta.Meta
    | Verbatim String String Evergreen.V31.Parser.Meta.Meta
    | Error String
