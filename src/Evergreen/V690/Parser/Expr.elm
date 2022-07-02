module Evergreen.V690.Parser.Expr exposing (..)

import Evergreen.V690.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V690.Parser.Meta.Meta
    | Text String Evergreen.V690.Parser.Meta.Meta
    | Verbatim String String Evergreen.V690.Parser.Meta.Meta
