module Evergreen.V509.Parser.Expr exposing (..)

import Evergreen.V509.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V509.Parser.Meta.Meta
    | Text String Evergreen.V509.Parser.Meta.Meta
    | Verbatim String String Evergreen.V509.Parser.Meta.Meta
