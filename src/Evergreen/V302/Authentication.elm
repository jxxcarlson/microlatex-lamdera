module Evergreen.V302.Authentication exposing (..)

import Dict
import Evergreen.V302.Credentials
import Evergreen.V302.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V302.User.User
    , credentials : Evergreen.V302.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
