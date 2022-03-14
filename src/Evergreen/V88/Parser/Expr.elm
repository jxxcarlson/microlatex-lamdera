module Evergreen.V88.Parser.Expr exposing (..)

import Evergreen.V88.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V88.Parser.Meta.Meta
    | Text String Evergreen.V88.Parser.Meta.Meta
    | Verbatim String String Evergreen.V88.Parser.Meta.Meta
