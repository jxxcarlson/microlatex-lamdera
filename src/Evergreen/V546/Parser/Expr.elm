module Evergreen.V546.Parser.Expr exposing (..)

import Evergreen.V546.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V546.Parser.Meta.Meta
    | Text String Evergreen.V546.Parser.Meta.Meta
    | Verbatim String String Evergreen.V546.Parser.Meta.Meta
