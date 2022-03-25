module Evergreen.V167.Parser.Expr exposing (..)

import Evergreen.V167.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V167.Parser.Meta.Meta
    | Text String Evergreen.V167.Parser.Meta.Meta
    | Verbatim String String Evergreen.V167.Parser.Meta.Meta
