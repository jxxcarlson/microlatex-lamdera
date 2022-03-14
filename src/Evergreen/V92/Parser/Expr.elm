module Evergreen.V92.Parser.Expr exposing (..)

import Evergreen.V92.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V92.Parser.Meta.Meta
    | Text String Evergreen.V92.Parser.Meta.Meta
    | Verbatim String String Evergreen.V92.Parser.Meta.Meta
