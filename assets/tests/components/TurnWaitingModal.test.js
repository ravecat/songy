import { render, screen, fireEvent } from "@testing-library/svelte";
import { expect, test, describe } from "vitest";
import TurnWaitingModal from "@components/TurnWaitingModal.svelte";

describe("TurnWaitingModal", () => {
  test("renders modal when isOpen is true", () => {
    const mockClose = () => {};

    render(TurnWaitingModal, {
      props: {
        isOpen: true,
        close: mockClose,
      },
    });

    expect(screen.getByText("Turn Waiting")).toBeInTheDocument();
    expect(screen.getByText("Waiting for your turn...")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "OK" })).toBeInTheDocument();
  });

  test("does not render modal when isOpen is false", () => {
    const mockClose = () => {};

    render(TurnWaitingModal, {
      props: {
        isOpen: false,
        close: mockClose,
      },
    });

    expect(screen.queryByText("Turn Waiting")).not.toBeInTheDocument();
    expect(
      screen.queryByText("Waiting for your turn...")
    ).not.toBeInTheDocument();
  });

  test("calls close function when OK button is clicked", async () => {
    let closeCalled = false;
    const mockClose = () => {
      closeCalled = true;
    };

    render(TurnWaitingModal, {
      props: {
        isOpen: true,
        close: mockClose,
      },
    });

    const button = screen.getByRole("button", { name: "OK" });
    await fireEvent.click(button);

    expect(closeCalled).toBe(true);
  });

  test("has correct accessibility attributes", () => {
    const mockClose = () => {};

    render(TurnWaitingModal, {
      props: {
        isOpen: true,
        close: mockClose,
      },
    });

    const dialog = screen.getByRole("dialog", { hidden: true });
    expect(dialog).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "OK" })).toBeInTheDocument();
  });

  test("dialog element is present when modal is open", () => {
    const mockClose = () => {};

    render(TurnWaitingModal, {
      props: {
        isOpen: true,
        close: mockClose,
      },
    });

    expect(screen.getByRole("dialog", { hidden: true })).toBeInTheDocument();
  });

  test("dialog element is not present when modal is closed", () => {
    const mockClose = () => {};

    render(TurnWaitingModal, {
      props: {
        isOpen: false,
        close: mockClose,
      },
    });

    expect(
      screen.queryByRole("dialog", { hidden: true })
    ).not.toBeInTheDocument();
  });

  test("button has autofocus attribute", () => {
    const mockClose = () => {};

    render(TurnWaitingModal, {
      props: {
        isOpen: true,
        close: mockClose,
      },
    });

    const button = screen.getByRole("button", { name: "OK" });
    expect(button).toHaveAttribute("autofocus");
  });

  test("dialog can be closed by clicking outside", async () => {
    let closeCalled = false;
    const mockClose = () => {
      closeCalled = true;
    };

    render(TurnWaitingModal, {
      props: {
        isOpen: true,
        close: mockClose,
      },
    });

    const dialog = screen.getByRole("dialog", { hidden: true });

    // Simulate clicking on the dialog backdrop (the dialog element itself)
    await fireEvent.click(dialog);

    expect(closeCalled).toBe(true);
  });

  test("dialog does not close when clicking inside content", async () => {
    let closeCalled = false;
    const mockClose = () => {
      closeCalled = true;
    };

    render(TurnWaitingModal, {
      props: {
        isOpen: true,
        close: mockClose,
      },
    });

    const heading = screen.getByText("Turn Waiting");
    await fireEvent.click(heading);

    expect(closeCalled).toBe(false);
  });

  test("modal has correct heading hierarchy", () => {
    const mockClose = () => {};

    render(TurnWaitingModal, {
      props: {
        isOpen: true,
        close: mockClose,
      },
    });

    expect(screen.getByRole("heading", { level: 2 })).toHaveTextContent(
      "Turn Waiting"
    );
  });
});
