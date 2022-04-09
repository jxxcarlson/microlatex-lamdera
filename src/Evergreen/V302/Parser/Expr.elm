module Evergreen.V302.Parser.Expr exposing (..)

import Evergreen.V302.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V302.Parser.Meta.Meta
    | Text String Evergreen.V302.Parser.Meta.Meta
    | Verbatim String String Evergreen.V302.Parser.Meta.Meta
