module Evergreen.V701.Authentication exposing (..)

import Dict
import Evergreen.V701.Credentials
import Evergreen.V701.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V701.User.User
    , credentials : Evergreen.V701.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
