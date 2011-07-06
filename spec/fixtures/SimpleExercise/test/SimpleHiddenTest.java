
import fi.helsinki.cs.tmc.testrunner.Exercise;
import org.junit.Test;
import static org.junit.Assert.*;

public class SimpleHiddenTest {
    @Test
    @Exercise("mul")
    public void testMultiply() {
        assertEquals(12, SimpleStuff.multiply(4, 3));
        assertEquals(0, SimpleStuff.multiply(0, 0));
        assertEquals(2, SimpleStuff.multiply(-1, -2));
    }
    
}
