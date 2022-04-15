module Evergreen.V378.Parser.Expr exposing (..)

import Evergreen.V378.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V378.Parser.Meta.Meta
    | Text String Evergreen.V378.Parser.Meta.Meta
    | Verbatim String String Evergreen.V378.Parser.Meta.Meta
