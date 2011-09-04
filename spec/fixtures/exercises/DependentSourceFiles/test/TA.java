import org.junit.Test;
import fi.helsinki.cs.tmc.testrunner.Points;

@Points("ta")
public class TA {
  @Test
  public void foo() {
      new A().b();
  }
}
