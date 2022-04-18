module Evergreen.V409.Parser.Expr exposing (..)

import Evergreen.V409.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V409.Parser.Meta.Meta
    | Text String Evergreen.V409.Parser.Meta.Meta
    | Verbatim String String Evergreen.V409.Parser.Meta.Meta
