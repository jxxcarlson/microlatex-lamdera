module Evergreen.V503.Parser.Expr exposing (..)

import Evergreen.V503.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V503.Parser.Meta.Meta
    | Text String Evergreen.V503.Parser.Meta.Meta
    | Verbatim String String Evergreen.V503.Parser.Meta.Meta
