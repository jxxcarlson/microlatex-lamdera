module Evergreen.V453.Compiler.DifferentialParser exposing (..)

import Evergreen.V453.Compiler.AbstractDifferentialParser
import Evergreen.V453.Compiler.Acc
import Evergreen.V453.Parser.Block
import Evergreen.V453.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V453.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V453.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V453.Parser.Block.ExpressionBlock) Evergreen.V453.Compiler.Acc.Accumulator
