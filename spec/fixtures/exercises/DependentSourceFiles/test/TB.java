import org.junit.Test;
import fi.helsinki.cs.tmc.edutestutils.Points;

@Points("tb")
public class TB {
  @Test
  public void foo() {
      new B().a();
  }
}
