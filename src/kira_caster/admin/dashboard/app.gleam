import kira_caster/admin/dashboard/effects
import kira_caster/admin/dashboard/model.{
  type DashboardContext, type Model, type Msg,
}
import kira_caster/admin/dashboard/update
import kira_caster/admin/dashboard/view
import lustre
import lustre/effect

pub fn create() {
  lustre.application(init, update.update, view.view)
}

fn init(ctx: DashboardContext) -> #(Model, effect.Effect(Msg)) {
  #(
    model.new(ctx),
    effect.batch([
      effects.load_tab(model.Status, ctx),
      effects.schedule_refresh(),
    ]),
  )
}
