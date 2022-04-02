module Evergreen.V221.Compiler.DifferentialParser exposing (..)

import Evergreen.V221.Compiler.AbstractDifferentialParser
import Evergreen.V221.Compiler.Acc
import Evergreen.V221.Parser.Block
import Evergreen.V221.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V221.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V221.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V221.Parser.Block.ExpressionBlock) Evergreen.V221.Compiler.Acc.Accumulator
