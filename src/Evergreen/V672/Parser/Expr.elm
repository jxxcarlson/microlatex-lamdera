module Evergreen.V672.Parser.Expr exposing (..)

import Evergreen.V672.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V672.Parser.Meta.Meta
    | Text String Evergreen.V672.Parser.Meta.Meta
    | Verbatim String String Evergreen.V672.Parser.Meta.Meta
