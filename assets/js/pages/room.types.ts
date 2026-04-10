import type { PageProps, SharedPageProps } from "@inertiajs/core";

export type Props = PageProps &
  SharedPageProps & {
    roomId: string;
    qr?: string;
  };
