module Evergreen.V428.Parser.Expr exposing (..)

import Evergreen.V428.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V428.Parser.Meta.Meta
    | Text String Evergreen.V428.Parser.Meta.Meta
    | Verbatim String String Evergreen.V428.Parser.Meta.Meta
