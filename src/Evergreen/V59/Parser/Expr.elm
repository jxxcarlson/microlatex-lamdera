module Evergreen.V59.Parser.Expr exposing (..)

import Evergreen.V59.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V59.Parser.Meta.Meta
    | Text String Evergreen.V59.Parser.Meta.Meta
    | Verbatim String String Evergreen.V59.Parser.Meta.Meta
    | Error String
