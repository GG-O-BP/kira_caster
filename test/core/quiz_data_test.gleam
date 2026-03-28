import gleam/list
import kira_caster/core/quiz_data

pub fn all_returns_15_quizzes_test() {
  assert list.length(quiz_data.all()) == 15
}

pub fn count_matches_all_length_test() {
  assert quiz_data.count() == list.length(quiz_data.all())
}

pub fn all_quizzes_have_answers_test() {
  let has_answers =
    list.all(quiz_data.all(), fn(q) { !list.is_empty(q.answers) })
  assert has_answers == True
}

pub fn all_quizzes_have_positive_reward_test() {
  let positive = list.all(quiz_data.all(), fn(q) { q.reward > 0 })
  assert positive == True
}

pub fn all_questions_unique_test() {
  let questions = list.map(quiz_data.all(), fn(q) { q.question })
  assert list.length(questions) == list.length(list.unique(questions))
}
