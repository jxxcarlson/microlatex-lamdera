module Evergreen.V41.Parser.Expr exposing (..)

import Evergreen.V41.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V41.Parser.Meta.Meta
    | Text String Evergreen.V41.Parser.Meta.Meta
    | Verbatim String String Evergreen.V41.Parser.Meta.Meta
    | Error String
