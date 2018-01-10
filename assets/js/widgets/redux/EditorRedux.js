import _ from 'lodash';
import Immutable from 'seamless-immutable';
import { createReducer } from 'reduxsauce';
import { firstUserSelector, secondUserSelector, currentUserSelector } from '../selectors/user';
import { EditorTypes as Types } from './Actions';
import userTypes from '../config/userTypes';

/* ------------- Initial State ------------- */

export const INITIAL_STATE = Immutable({
  editors: {
    // 1: { userId: 1, value: '', currentLang: null },
    // 2: { userId: 2, value: '', currentLang: null },
  },
});

/* ------------- Reducers ------------- */

const updateEditorData = (state, { userId, editorText, currentLang }) =>
  state.updateIn(['editors'], Immutable.merge, { [userId]: { userId, value: editorText, currentLang } });

const updateEditorText = (state, { userId, editorText }) =>
  state.updateIn(
    ['editors'],
    Immutable.merge,
    { [userId]: { userId, value: editorText } },
    { deep: true },
  );

const updateEditorLang = (state, { userId, currentLang }) =>
  state.updateIn(
    ['editors'],
    Immutable.merge,
    { [userId]: { userId, currentLang } },
    { deep: true },
  );

/* ------------- Hookup Reducers To Types ------------- */
export const reducer = createReducer(INITIAL_STATE, {
  [Types.UPDATE_EDITOR_DATA]: updateEditorData,
  [Types.UPDATE_EDITOR_TEXT]: updateEditorText,
  [Types.UPDATE_EDITOR_LANG]: updateEditorLang,
});

/* ------------- Selectors ------------- */

export const editorsSelector = state => state.editors.editors;

export const firstEditorSelector = (state) => {
  const editor = _.pickBy(editorsSelector(state), { userId: firstUserSelector(state).id });
  return _.values(editor)[0];
};

export const secondEditorSelector = (state) => {
  const editor = _.pickBy(editorsSelector(state), { userId: secondUserSelector(state).id });
  return _.values(editor)[0];
};

export const leftEditorSelector = (state) => {
  const currentUser = currentUserSelector(state);
  const editorSelector = (currentUser.type !== userTypes.secondPlayer) ?
    firstEditorSelector :
    secondEditorSelector;
  return editorSelector(state);
};

export const rightEditorSelector = (state) => {
  const currentUser = currentUserSelector(state);
  const editorSelector = (currentUser.type === userTypes.secondPlayer) ?
    firstEditorSelector :
    secondEditorSelector;
  return editorSelector(state);
};

export const langSelector = (userId, state) =>
  _.get(state, ['editors', 'editors', userId, 'currentLang'], null);
