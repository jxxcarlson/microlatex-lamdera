module Evergreen.V505.Parser.Expr exposing (..)

import Evergreen.V505.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V505.Parser.Meta.Meta
    | Text String Evergreen.V505.Parser.Meta.Meta
    | Verbatim String String Evergreen.V505.Parser.Meta.Meta
