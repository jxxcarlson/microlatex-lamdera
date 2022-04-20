module Evergreen.V430.Parser.Expr exposing (..)

import Evergreen.V430.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V430.Parser.Meta.Meta
    | Text String Evergreen.V430.Parser.Meta.Meta
    | Verbatim String String Evergreen.V430.Parser.Meta.Meta
