module Evergreen.V279.Parser.Expr exposing (..)

import Evergreen.V279.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V279.Parser.Meta.Meta
    | Text String Evergreen.V279.Parser.Meta.Meta
    | Verbatim String String Evergreen.V279.Parser.Meta.Meta
