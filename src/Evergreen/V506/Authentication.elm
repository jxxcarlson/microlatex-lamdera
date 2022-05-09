module Evergreen.V506.Authentication exposing (..)

import Dict
import Evergreen.V506.Credentials
import Evergreen.V506.User


type alias Username =
    String


type alias UserData =
    { user : Evergreen.V506.User.User
    , credentials : Evergreen.V506.Credentials.Credentials
    }


type alias AuthenticationDict =
    Dict.Dict Username UserData
