module Evergreen.V353.Parser.Expr exposing (..)

import Evergreen.V353.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V353.Parser.Meta.Meta
    | Text String Evergreen.V353.Parser.Meta.Meta
    | Verbatim String String Evergreen.V353.Parser.Meta.Meta
