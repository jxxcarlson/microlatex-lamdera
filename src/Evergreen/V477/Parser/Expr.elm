module Evergreen.V477.Parser.Expr exposing (..)

import Evergreen.V477.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V477.Parser.Meta.Meta
    | Text String Evergreen.V477.Parser.Meta.Meta
    | Verbatim String String Evergreen.V477.Parser.Meta.Meta
