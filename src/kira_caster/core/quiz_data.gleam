/// 퀴즈 데이터 모듈.
/// 현재는 내장 데이터를 사용하며, 추후 DB + 대시보드를 통해
/// 스트리머가 직접 퀴즈를 추가/삭제/수정할 수 있도록 확장 예정.
pub type Quiz {
  Quiz(question: String, answers: List(String), reward: Int)
}

pub fn all() -> List(Quiz) {
  [
    Quiz(question: "스토푸리의 정식 명칭은?", answers: ["스트로베리 프린스"], reward: 10),
    Quiz(question: "스토푸리의 리더는 누구?", answers: ["나나모리"], reward: 10),
    Quiz(
      question: "스토푸리가 결성된 날짜는? (YYYY-MM-DD)",
      answers: ["2016-06-04"],
      reward: 20,
    ),
    Quiz(question: "리누의 멤버 컬러는?", answers: ["빨강", "빨간색", "레드"], reward: 10),
    Quiz(question: "루토의 멤버 컬러는?", answers: ["노랑", "노란색", "옐로우"], reward: 10),
    Quiz(
      question: "코론의 멤버 컬러는?",
      answers: ["하늘색", "파랑", "파란색", "블루", "스카이블루"],
      reward: 10,
    ),
    Quiz(question: "사토미의 멤버 컬러는?", answers: ["핑크", "분홍", "분홍색"], reward: 10),
    Quiz(question: "제루의 멤버 컬러는?", answers: ["오렌지", "주황", "주황색"], reward: 10),
    Quiz(question: "나나모리의 멤버 컬러는?", answers: ["보라", "보라색", "퍼플"], reward: 10),
    Quiz(question: "스토푸리에서 작곡을 주로 담당하는 최연소 멤버는?", answers: ["루토"], reward: 15),
    Quiz(question: "스토푸리의 첫 번째 미니앨범 이름은?", answers: ["스트로베리 스타트"], reward: 20),
    Quiz(
      question: "요괴워치 애니메이션 오프닝으로 사용된 스토푸리 곡은?",
      answers: ["반짝쿵은하"],
      reward: 20,
    ),
    Quiz(
      question: "스토푸리 멤버 중 관서 사투리(칸사이벤)가 매력인 멤버는?",
      answers: ["제루"],
      reward: 15,
    ),
    Quiz(question: "스토푸리 멤버 중 최연장자는?", answers: ["사토미"], reward: 15),
    Quiz(question: "스토푸리 팬들의 이름은?", answers: ["스토푸리스나", "스토푸리스너"], reward: 15),
  ]
}

pub fn count() -> Int {
  15
}
