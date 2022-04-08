module Evergreen.V295.Parser.Expr exposing (..)

import Evergreen.V295.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V295.Parser.Meta.Meta
    | Text String Evergreen.V295.Parser.Meta.Meta
    | Verbatim String String Evergreen.V295.Parser.Meta.Meta
