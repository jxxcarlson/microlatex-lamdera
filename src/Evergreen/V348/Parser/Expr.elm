module Evergreen.V348.Parser.Expr exposing (..)

import Evergreen.V348.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V348.Parser.Meta.Meta
    | Text String Evergreen.V348.Parser.Meta.Meta
    | Verbatim String String Evergreen.V348.Parser.Meta.Meta
