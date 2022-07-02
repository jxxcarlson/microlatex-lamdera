module Evergreen.V683.Parser.Expr exposing (..)

import Evergreen.V683.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V683.Parser.Meta.Meta
    | Text String Evergreen.V683.Parser.Meta.Meta
    | Verbatim String String Evergreen.V683.Parser.Meta.Meta
