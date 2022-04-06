module Evergreen.V269.Parser.Expr exposing (..)

import Evergreen.V269.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V269.Parser.Meta.Meta
    | Text String Evergreen.V269.Parser.Meta.Meta
    | Verbatim String String Evergreen.V269.Parser.Meta.Meta
