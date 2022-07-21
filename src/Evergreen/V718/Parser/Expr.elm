module Evergreen.V718.Parser.Expr exposing (..)

import Evergreen.V718.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V718.Parser.Meta.Meta
    | Text String Evergreen.V718.Parser.Meta.Meta
    | Verbatim String String Evergreen.V718.Parser.Meta.Meta
