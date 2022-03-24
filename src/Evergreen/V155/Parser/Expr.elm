module Evergreen.V155.Parser.Expr exposing (..)

import Evergreen.V155.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V155.Parser.Meta.Meta
    | Text String Evergreen.V155.Parser.Meta.Meta
    | Verbatim String String Evergreen.V155.Parser.Meta.Meta
