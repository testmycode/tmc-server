
import fi.helsinki.cs.tmc.edutestutils.Points;
import org.junit.Test;
import static org.junit.Assert.*;

public class BTest {
    @Test
    @Points("test2")
    public void test2() throws Exception {
        Main.theMethod();
    }
}
