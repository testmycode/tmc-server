
import fi.helsinki.cs.tmc.testrunner.Exercise;
import org.junit.Test;
import static org.junit.Assert.*;

public class SimpleTest {
    @Test
    @Exercise("addsub")
    public void testAdd() {
        assertEquals(9, SimpleStuff.add(3, 6));
        assertEquals(-2, SimpleStuff.add(-9, 7));
    }
    
    @Exercise("addsub")
    public void testSubtract() {
        assertEquals(3, SimpleStuff.subtract(7, 4));
        assertEquals(-333, SimpleStuff.subtract(123, 456));
    }
}
